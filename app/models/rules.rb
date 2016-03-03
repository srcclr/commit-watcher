Sequel::Model.plugin(:validation_helpers)
class Rules < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:name, :rule_type_id, :value]

    validates_unique :name
    validates_min_length 3, :name, message: proc { |s| "must be more than #{s} characters" }
    validates_format /[A-Za-z0-9\-\._ ]/,
        :name,
        message: 'invalid name; can include letters, numbers, space, and "-", ".", "_"'

    validates_includes RuleTypes.keys, :rule_type_id

    begin
        Regexp.new(value)
    rescue RegexpError => e
        errors.add(:value, "invalid value pattern: #{e}")
    end
  end
end
