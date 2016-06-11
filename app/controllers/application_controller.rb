# Application controller
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_action :test_singleton

  protect_from_forgery with: :exception

  layout :layout_by_resource

  protected

  def layout_by_resource
    if devise_controller?
      'admin/application'
    else
      'application'
    end
  end

  def test_singleton
    instance = CommandHistoryManager.get_instance
    puts '*' * 50
    puts instance.increase_counter
  end
end
