class ExternallySubmittedPeopleController < ApplicationController
  skip_authorization_check

  respond_to :js

  def devise_controller?
    true
  end

  def create
    ActiveRecord::Base.transaction do
      @person = Person.create(first_name: first_name,
                              last_name: last_name,
                              email: email)

      if zip_codes_matching_groups.any?
        zip_codes_matching_groups.each do |group|
          case submitted_role
          when "Mitglied", "Sympathisant"
            if zugeordnete_children(group).any?
              put_him_into_zugeordnete_children zugeordnete_children(group)
            else
              put_him_into_root_zugeordnete_groups
            end
          when "Adressverwaltung"
            if kontakte_children(group).any?
              put_him_into_kontakte_children kontakte_children(group)
            else
              put_him_into_root_kontakte_groups
            end
          end
        end
      else
        case submitted_role
        when "Mitglied", "Sympathisant"
          put_him_into_root_zugeordnete_groups
        when "Adressverwaltung"
          put_him_into_root_kontakte_groups
        end
      end
    end
  end

  private

  def put_him_into_root_zugeordnete_groups
    root_zugeordnete_groups.each do |group|
      Role.create(type:   zugeordnete_role_type,
                  person: @person,
                  group:  group)
    end
  end

  def put_him_into_root_kontakte_groups
    root_kontakte_groups.each do |group|
      Role.create!(type:   kontakte_role_type,
                   person: @person,
                   group:  group)
    end
  end

  def root_zugeordnete_groups
    Group.where(type: "Group::RootZugeordnete")
  end

  def root_kontakte_groups
    Group.where(type: "Group::RootKontakte")
  end

  def zugeordnete_role_type
    "Group::RootZugeordnete::#{submitted_role}"
  end

  def kontakte_role_type
    "Group::RootKontakte::#{submitted_role}"
  end

  def zip_codes_matching_groups
    groups_with_zip_codes = Group.where.not(zip_codes: '')
    groups_with_zip_codes.select do |group|
      group.zip_codes.split(",").map(&:strip).include? externally_submitted_person_params[:zip_code]
    end
  end

  def zugeordnete_children group
    if group.children.any?
      @zugeordnete_children ||= group.children.select{ |child| child.type.include?("Zugeordnete")}
    else
      []
    end
  end

  def kontakte_children group
    if group.children.any?
      @kontakte_children ||= group.children.select{ |child| child.type.include?("Kontakte")}
    else
      []
    end
  end

  def put_him_into_zugeordnete_children zugeordnete_children
    zugeordnete_children.each do |zugeordnete_child|
      Role.create!(type:   "#{zugeordnete_child.type}::#{submitted_role}",
                   person: @person,
                   group:  zugeordnete_child)
    end
  end

  def put_him_into_kontakte_children kontakte_children
    kontakte_children.each do |kontakte_child|
      Role.create!(type:   "#{kontakte_child.type}::#{submitted_role}",
                   person: @person,
                   group:  kontakte_child)
    end
  end

  def submitted_role
    externally_submitted_person_params[:role].capitalize
  end

  def first_name
    externally_submitted_person_params[:first_name]
  end

  def last_name
    externally_submitted_person_params[:last_name]
  end

  def email
    externally_submitted_person_params[:email]
  end

  def externally_submitted_person_params
    params.require(:externally_submitted_person).permit(:email, :zip_code, :role, :first_name, :last_name)
  end
end
