module ActiveAdmin
  class Comment < ActiveRecord::Base

    self.table_name = 'active_admin_comments'

    belongs_to :resource, polymorphic: true
    belongs_to :author,   polymorphic: true
    has_many :replies, inverse_of: :replied_to, class_name: "ActiveAdmin::Comment", foreign_key: "replied_to_id", dependent: :destroy
    belongs_to :replied_to, class_name: "ActiveAdmin::Comment", foreign_key: "replied_to_id",  inverse_of: :replies
    has_many :email_responders, class_name: 'EmailResponder', foreign_key: :resource_id, foreign_type: :resource_type, inverse_of: :resource

    def is_reply?
      !self.replied_to.nil?
    end

    def original_comment
      is_reply? ? self.replied_to.original_comment : self
    end

    if defined? ProtectedAttributes
      attr_accessible :resource, :resource_id, :resource_type, :body, :namespace
    end

    validates_presence_of :body, :namespace, :resource

    before_create :set_resource_type

    # @return [String] The name of the record to use for the polymorphic relationship
    def self.resource_type(resource)
      ResourceController::Decorators.undecorate(resource).class.base_class.name.to_s
    end

    # Postgres adapters won't compare strings to numbers (issue 34)
    def self.resource_id_cast(record)
      resource_id_type == :string ? record.id.to_s : record.id
    end

    def self.find_for_resource_in_namespace(resource, namespace)
      where(
        resource_type: resource_type(resource),
        resource_id:   resource_id_cast(resource),
        namespace:     namespace.to_s
      ).order(ActiveAdmin.application.namespaces[namespace.to_sym].comments_order)
    end

    def self.resource_id_type
      columns.detect{ |i| i.name == "resource_id" }.type
    end

    def set_resource_type
      self.resource_type = self.class.resource_type(resource)
    end

  end
end
