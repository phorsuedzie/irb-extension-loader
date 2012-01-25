irb_activate 'wirble' do
  Wirble.init
  Wirble.colorize if irb_config[:wirble]
end
