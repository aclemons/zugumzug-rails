SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'

  add_group 'Services', 'app/services'

end
