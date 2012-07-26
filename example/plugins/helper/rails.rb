def rails?
  defined?(::Rails) || ::ENV.key?('RAILS_ENV')
end
