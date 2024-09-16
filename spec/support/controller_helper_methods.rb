module ControllerHelperMethods
  def current_team
    @current_team ||= FactoryBot.create(:team)
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user
  end

  def current_designer
    @current_designer ||= current_user
  end

  def admin_or_manager?
    current_user&.admin_or_manager?
  end

  def designer?
    current_user&.designer?
  end
end
