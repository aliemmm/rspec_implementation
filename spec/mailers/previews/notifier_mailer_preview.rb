# Preview all emails at http://localhost:3001/rails/mailers
class NotifierMailerPreview < ActionMailer::Preview
  def decline_project
    NotifierMailer.decline_project(User.where(role: :designer).first,
      User.where(role: :client).first,
      "Sorry, can't accept your project now")
  end

  def edesign_book
    NotifierMailer.edesign_book(Lead.find_by(kind: "edesign-book"))
  end

  def edesign_event_business
    NotifierMailer.edesign_event_business(Lead.find_by(kind: "edesign-event-2023"))
  end

  def affiliate_book
    NotifierMailer.affiliate_book(Lead.find_by(kind: "affiliate-book"))
  end

  def moodboards
    NotifierMailer.moodboards(Lead.find_by(kind: "moodboards"))
  end

  def invoice_confirmation
    designer = User.find_by(email: "designer@df.co")
    invoice = Invoice.where(status: :partial).last
    NotifierMailer.invoice_confirmation(invoice, invoice.invoice_payments.first, true, designer)
  end

  def contract
    contract = Contract.first
    designer = contract.project.designer
    recipient_email = contract.client.email
    send_contract_params = {
      message_subject: "This is test subject message",
      message_body: "Please find contract attached to this mail"
    }
    NotifierMailer.contract(designer, contract, recipient_email, send_contract_params)
  end

  def contract_signed
    designer = User.find_by(email: "designer@df.co")
    contract = Contract.where(status: :signed).first
    NotifierMailer.contract_signed(contract, designer)
  end

  def invoice
    designer = User.find_by(email: "designer@df.co")
    invoice = Invoice.where.not(status: :draft).where.not(refund_invoice: true).first
    send_invoice_params = {
      message_subject: "This is test subject message",
      message_body: "Please find invoice attached to this mail"
    }

    NotifierMailer.invoice(designer, invoice, invoice.client.email, send_invoice_params)
  end

  def refund_invoice
    designer = User.find_by(email: "designer@df.co")
    invoice = Invoice.where.not(status: :draft).where.not(refund_invoice: false).last
    send_invoice_params = {
      message_subject: "This is test subject message",
      message_body: "Please find refund invoice attached to this mail"
    }

    NotifierMailer.refund_invoice(designer, invoice, invoice.client.email, send_invoice_params)
  end

  def retainer
    designer = User.find_by(email: "designer@df.co")
    retainer = Retainer.where.not(status: :draft).first
    send_invoice_params = {
      message_subject: "This is test subject message",
      message_body: "Please find a copy of your Retainer Invoice below:"
    }

    NotifierMailer.retainer(designer, retainer, retainer.client.email, send_invoice_params)
  end

  def retainer_confirmation
    designer = User.find_by(email: "designer@df.co")
    retainer = Retainer.where(status: :partial).last

    NotifierMailer.retainer_confirmation(retainer, retainer.retainer_payments.first, designer)
  end

  def retainer_payment_receipt
    retainer = Retainer.where(status: :paid).last
    retainer_payment = retainer.retainer_payments.last

    NotifierMailer.retainer_payment_receipt(retainer, retainer_payment)
  end

  def quote
    designer = User.find_by(email: "designer@df.co")
    quote = Quote.first
    send_po_params = {
      message_subject: "Subject",
      message_body: "Your Designer has sent you a quote for the following project:"
    }
    NotifierMailer.quote(designer, quote, "client@df.co", send_po_params)
  end

  def spec_sheet
    designer = User.find_by(email: "designer@df.co")
    spec_sheet = SpecSheet.last
    recipient_email = "contractor@df.co"
    send_po_params = {
      message_subject: "This is test subject message",
      message_body: "Please find purchase order attached to this mail"
    }

    NotifierMailer.spec_sheet(designer, spec_sheet, recipient_email, send_po_params)
  end

  def quote_approved
    designer = User.find_by(email: "designer@df.co")
    quote = Quote.where(status: :approved).last
    NotifierMailer.quote_approved(quote, quote.client, designer)
  end

  def questionnaire_request
    NotifierMailer.questionnaire_request(User.find_by(email: "designer@df.co"),
      "client@df.co",
      Project.first,
      "Lorem ipsum message")
  end

  def discussion_comment_for_client
    NotifierMailer.discussion_comment(Comment.first, User.where(role: :client).first)
  end

  def discussion_comment_for_designer
    NotifierMailer.discussion_comment(Comment.first, User.where(role: :designer).first)
  end

  def project_assigned
    project = Project.first
    NotifierMailer.project_assigned(project, project.team.admin, project.designer)
  end

  def privte_note_board
    user = User.find_by(email: "fullservice@df.co")
    comment = user.comments.find_by(kind: :private_note, commentable_type: "Board")
    NotifierMailer.private_note(comment, user)
  end

  def privte_note_shoppable
    user = User.find_by(email: "fullservice@df.co")
    comment = user.comments.find_by(kind: :private_note, commentable_type: "BoardItem")
    NotifierMailer.private_note(comment, user)
  end

  def invite_client
    NotifierMailer.invite_client("test@test.com", "Start an online design consultation with me today!",
      User.find_by(role: "designer"), true)
  end

  def invite_designer
    NotifierMailer.invite_designer(DesignerInvite.first)
  end

  def job_request
    NotifierMailer.job_request(Project.first, Project.first.designer)
  end

  def project_update
    NotifierMailer.project_update(Project.first, User.where(role: :client).first)
  end

  def published_board
    NotifierMailer.published_board(User.where(role: :client).first.email, Board.first,
      "Text provided by designer", 1,
      User.where(role: :designer).first)
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(User.first, "faketoken")
  end

  def package_purchase_receipt
    design_package = DesignPackage.last
    project = design_package.projects.last
    NotifierMailer.package_purchase_receipt(design_package, design_package.team.admin, project.clients.last)
  end

  def invoice_payment_receipt
    invoice = params[:invoice_id].present? ? Invoice.find(params[:invoice_id]) : Invoice.where(status: :partial).last
    invoice_payment = if params[:invoice_payment_id]
      invoice.invoice_payments.find(params[:invoice_payment_id])
    else
      invoice.invoice_payments.first
    end

    NotifierMailer.invoice_payment_receipt(invoice, invoice_payment)
  end

  def approval_state
    board_shoppable = BoardProduct.where(approval_state: :approved).last
    client = board_shoppable.board.project.clients.last

    NotifierMailer.approval_state(client, board_shoppable)
  end

  def project_attachment_by_designer
    @user_file = UserFile.last
    @client = @user_file.project.clients.first

    NotifierMailer.project_attachment_by_designer(@user_file, @client)
  end

  def project_attachment_by_client
    designer = User.find_by(email: "designer@df.co")
    @user_file = UserFile.last

    NotifierMailer.project_attachment_by_client(@user_file, designer)
  end

  def purchase_order
    designer = User.find_by(email: "designer@df.co")
    purchase_order = PurchaseOrder.first
    recipient_email = "vendor@df.co"
    send_po_params = {
      message_subject: "This is test subject message",
      message_body: "Please find a copy of your purchase order below:"
    }

    NotifierMailer.purchase_order(designer, purchase_order, recipient_email, send_po_params)
  end

  def ach_payment_pending_invoice
    invoice = Invoice.where(status: :pending).last
    invoice_payment = invoice.invoice_payments.last

    NotifierMailer.ach_payment_pending(invoice, invoice_payment)
  end

  def ach_payment_failed_invoice
    invoice = Invoice.where(status: :failed).last
    invoice_payment = invoice.invoice_payments.last

    NotifierMailer.ach_payment_failed(invoice, invoice_payment)
  end

  def ach_payment_succeeded_invoice
    invoice = Invoice.where(status: :paid).last
    invoice_payment = invoice.invoice_payments.last

    NotifierMailer.ach_payment_succeeded(invoice, invoice_payment)
  end

  def ach_payment_succeeded_retainer
    retainer = Retainer.where(status: :paid).last
    retainer_payment = retainer.retainer_payments.last

    NotifierMailer.ach_payment_succeeded(retainer, retainer_payment)
  end

  def ach_payment_pending_retainer
    retainer = Retainer.where(status: :pending).last
    retainer_payment = retainer.retainer_payments.last

    NotifierMailer.ach_payment_pending(retainer, retainer_payment)
  end

  def ach_payment_failed_retainer
    retainer = Retainer.where(status: :failed).last
    retainer_payment = retainer.retainer_payments.last

    NotifierMailer.ach_payment_failed(retainer, retainer_payment)
  end

  def assigned_task
    NotifierMailer.assigned_task(Task.last)
  end

  def task_due_today
    task = if params[:task_id].present?
      Task.find(params[:task_id])
    else
      Task.where("assignee_id IS NOT NULL AND due_date IS NOT NULL").last
    end

    NotifierMailer.task_due_today(task)
  end

  def task_past_due_date
    task = if params[:task_id].present?
      Task.find(params[:task_id])
    else
      Task.not_completed.past_due.where.not(assignee: nil).last
    end

    NotifierMailer.task_past_due_date(task)
  end
end
