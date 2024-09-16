# Preview all emails at http://localhost:3001/rails/mailers
class SystemMailerPreview < ActionMailer::Preview
  def send_file
    SystemMailer.send_file "test"
  end

  def notify_fix
    SystemMailer.notify_fix(User.find_by(email: "designer@df.co").team_id)
  end
end
