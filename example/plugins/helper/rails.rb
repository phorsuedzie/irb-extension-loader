# provides irb_helper.rails?

irb_helper.instance_eval do
  def rails?
    defined?(::Rails) || ::ENV.key?('RAILS_ENV')
  end
end
