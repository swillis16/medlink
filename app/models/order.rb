class Order < ActiveRecord::Base
  belongs_to :user
  belongs_to :supply

  has_one :response

  validates_presence_of :user,   message: "unrecognized"
  validates_presence_of :supply, message: "unrecognized"

  validates_presence_of :location, message: "is missing"
  validates_presence_of :unit, message: "is missing"
  validates_presence_of :quantity, message: "is missing"

  validates_numericality_of :quantity, only_integer: true, on: :create

  scope :responded,   -> { includes(:response).references(:response
    ).where("responses.id IS NOT NULL") }
  scope :unresponded, -> { includes(:response).references(:response
    ).where("responses.id IS NULL")     }

  scope :past_due, -> { unresponded.where(["orders.created_at < ?",
    3.business_days.ago]) }
  scope :pending,  -> { unresponded.where(["orders.created_at >= ?",
    3.business_days.ago]) }

  scope :responded_by_country,   -> { includes(:response).references(:response
    ).where("responses.id IS NOT NULL") }
  scope :unresponded_by_country, -> { includes(:response).references(:response
    ).where("responses.id IS NULL")     }

  scope :past_due_by_country, -> { unresponded.where(["orders.created_at < ?",
    3.business_days.ago]) }
  scope :pending_by_country,  -> { unresponded.where(["orders.created_at >= ?",
    3.business_days.ago]) }

  def responded?
    response.present?
  end

  def responded_at
    response && response.created_at
  end

  def fulfilled?
    fulfilled_at.present?
  end

  validates_uniqueness_of :supply_id, scope: :user_id,
    conditions: -> { unresponded }

  def self.human_attribute_name(attr, options={})
    {
      user:   "PCV ID",
      supply: "shortcode"
    }[attr] || super
  end

  def self.create_from_text data
    user   = User.lookup   data[:pcvid]
    supply = Supply.lookup data[:shortcode]

    create!({
      user_id:   user.try(:id),
      phone:     data[:phone],
      email:     user.try(:email),
      supply_id: supply.try(:id),
      unit:      "#{data[:dosage_value]}#{data[:dosage_units]}",
      quantity:  data[:qty],
      location:  data[:loc] || user.try(:location)
    })
  end

  def confirmation_message
    if self.valid?
      I18n.t "order.confirmation"
    else
      errors.full_messages.join ","
    end
  end

  def full_dosage
    "#{dose}#{unit}"
  end
end

