RSpec.describe Calendar do
  let(:team) { create(:team) }
  let(:designer) { create(:user, :designer, team:) }
  let(:project) { create(:project, designers: [designer], created_by: designer) }

  describe ".prepare_calendar_entries" do
    let!(:all_day_single_day_event) { create(:calendar_event, :all_day_single_day, project:) }
    let!(:all_day_multiday_event) { create(:calendar_event, :all_day_multiday, project:) }
    let!(:non_all_day_same_day_event) { create(:calendar_event, :non_all_day_same_day, project:) }
    let!(:non_all_day_multiday_event) { create(:calendar_event, :non_all_day_multiday, project:) }
    let!(:yesterday_event) { create(:calendar_event, :yesterday, project:) }
    let!(:current_day_event) { create(:calendar_event, project:) }

    let!(:incomplete_task) { create(:task, :incomplete_task, project:, assigner_id: designer.id, team:) }
    let!(:completed_task) { create(:task, :completed_task, project:, assigner_id: designer.id, team:) }
    let!(:yesterday_task) do
      create(:task, :yesterday_completed_task, project:, assigner_id: designer.id, team:)
    end

    let(:purchase_order) { project.purchase_orders.create(issue_date: Date.parse("04/04/2023")) }
    let(:purchase_order_item) { create(:purchase_order_item, purchase_order:) }
    let!(:order_tracker_item) do
      create(:order_tracker_item, project:, trackable: purchase_order_item)
    end

    context "When called with monthly date range" do
      before { project.update_column(:due_date, "07/03/2023") }

      it "returns total 10 events" do
        events = project.prepare_calendar_entries(Date.parse("01/03/2023"), Date.parse("01/04/2023"))

        expect(events.count).to eq(10)

        expect(events.first[:event_id]).to eq(all_day_single_day_event.id)
        expect(events.first[:kind]).to eq("custom_event")
        expect(events.first[:start]).to eq(all_day_single_day_event.start_date.to_fs(:db))
        expect(events.first[:end]).to eq(all_day_single_day_event.end_date.next_day.to_fs(:db))
        expect(events.first[:is_yesterday]).to be(false)

        expect(events.second[:event_id]).to eq(all_day_multiday_event.id)
        expect(events.second[:kind]).to eq("custom_event")
        expect(events.second[:start]).to eq(all_day_multiday_event.start_date.to_fs(:db))
        expect(events.second[:end]).to eq(all_day_multiday_event.end_date.next_day.to_fs(:db))
        expect(events.second[:is_yesterday]).to be(false)

        expect(events.third[:event_id]).to eq(non_all_day_same_day_event.id)
        expect(events.third[:kind]).to eq("custom_event")
        expect(events.third[:start]).to eq(non_all_day_same_day_event.starts_at)
        expect(events.third[:end]).to eq(non_all_day_same_day_event.ends_at)
        expect(events.third[:is_yesterday]).to be(false)

        expect(events.fourth[:event_id]).to eq(non_all_day_multiday_event.id)
        expect(events.fourth[:kind]).to eq("custom_event")
        expect(events.fourth[:start]).to eq(non_all_day_multiday_event.starts_at)
        expect(events.fourth[:end]).to eq(non_all_day_multiday_event.ends_at)
        expect(events.fourth[:is_yesterday]).to be(false)

        expect(events.fifth[:task_id]).to eq(completed_task.id)
        expect(events.fifth[:start]).to eq(incomplete_task.due_date.to_fs(:tb))
        expect(events.fifth[:kind]).to eq("task_event")
        expect(events.fifth[:is_yesterday]).to be(false)
        expect(events.fifth[:is_completed]).to be(true)

        expect(events[5][:task_id]).to eq(incomplete_task.id)
        expect(events[5][:start]).to eq(completed_task.due_date.to_fs(:tb))
        expect(events[5][:kind]).to eq("task_event")
        expect(events[5][:is_yesterday]).to be(false)
        expect(events[5][:is_completed]).to be(false)

        # Ordered event
        expect(events[6][:start]).to eq(order_tracker_item.ordered_date.to_fs(:db))
        expect(events[6][:kind]).to eq("ordered_date")
        expect(events[6][:title]).to eq("Ordered: 1 Item")
        expect(events[6][:className]).to eq("fc-event-ordered")
        expect(events[6][:is_yesterday]).to be(false)

        # Shipping event
        expect(events[7][:start]).to eq(order_tracker_item.shipping_date.to_fs(:db))
        expect(events[7][:kind]).to eq("shipping_date")
        expect(events[7][:title]).to eq("Shipping: 1 Item")
        expect(events[7][:className]).to eq("fc-event-shipping")
        expect(events[7][:is_yesterday]).to be(false)

        # At receiver event
        expect(events[8][:start]).to eq(order_tracker_item.at_receiver_date.to_fs(:db))
        expect(events[8][:kind]).to eq("at_receiver_date")
        expect(events[8][:title]).to eq("At Receiver: 1 Item")
        expect(events[8][:className]).to eq("fc-event-at-receiver")
        expect(events[8][:is_yesterday]).to be(false)

        # Project due date event
        expect(events.last[:start]).to eq(project.due_date.to_fs(:db))
        expect(events.last[:kind]).to eq("project_due_date")
        expect(events.last[:title]).to eq("Due: #{project.name}")
        expect(events.last[:className]).to eq("fc-event-project-due-date")
        expect(events.last[:is_yesterday]).to be(false)
      end
    end

    context "When called with weekly date range" do
      before { project.update_column(:due_date, "08/03/2023") }

      it "returns 7 events" do
        events = project.prepare_calendar_entries(Date.parse("06/03/2023"), Date.parse("13/03/2023"))

        expect(events.count).to eq(7)

        expect(events.first[:event_id]).to eq(all_day_multiday_event.id)
        expect(events.first[:kind]).to eq("custom_event")
        expect(events.first[:start]).to eq(all_day_multiday_event.start_date.to_fs(:db))
        expect(events.first[:end]).to eq(all_day_multiday_event.end_date.next_day.to_fs(:db))
        expect(events.first[:is_yesterday]).to be(false)

        expect(events.second[:event_id]).to eq(non_all_day_multiday_event.id)
        expect(events.second[:kind]).to eq("custom_event")
        expect(events.second[:start]).to eq(non_all_day_multiday_event.starts_at)
        expect(events.second[:end]).to eq(non_all_day_multiday_event.ends_at)
        expect(events.second[:is_yesterday]).to be(false)

        expect(events.third[:task_id]).to eq(completed_task.id)
        expect(events.third[:start]).to eq(incomplete_task.due_date.to_fs(:tb))
        expect(events.third[:kind]).to eq("task_event")
        expect(events.third[:is_yesterday]).to be(false)
        expect(events.third[:is_completed]).to be(true)

        expect(events.fourth[:task_id]).to eq(incomplete_task.id)
        expect(events.fourth[:start]).to eq(completed_task.due_date.to_fs(:tb))
        expect(events.fourth[:kind]).to eq("task_event")
        expect(events.fourth[:is_yesterday]).to be(false)
        expect(events.fourth[:is_completed]).to be(false)

        # Shipping event
        expect(events.fifth[:start]).to eq(order_tracker_item.shipping_date.to_fs(:db))
        expect(events.fifth[:kind]).to eq("shipping_date")
        expect(events.fifth[:title]).to eq("Shipping: 1 Item")
        expect(events.fifth[:className]).to eq("fc-event-shipping")
        expect(events.fifth[:is_yesterday]).to be(false)

        # At receiver event
        expect(events[5][:start]).to eq(order_tracker_item.at_receiver_date.to_fs(:db))
        expect(events[5][:kind]).to eq("at_receiver_date")
        expect(events[5][:title]).to eq("At Receiver: 1 Item")
        expect(events[5][:className]).to eq("fc-event-at-receiver")
        expect(events[5][:is_yesterday]).to be(false)

        # Project due date event
        expect(events.last[:start]).to eq(project.due_date.to_fs(:db))
        expect(events.last[:kind]).to eq("project_due_date")
        expect(events.last[:title]).to eq("Due: #{project.name}")
        expect(events.last[:className]).to eq("fc-event-project-due-date")
        expect(events.last[:is_yesterday]).to be(false)
      end
    end

    context "When called with daily date range" do
      before { project.update_column(:due_date, Date.parse("03/03/2023")) }

      it "returns 6 events" do
        events = project.prepare_calendar_entries(Date.parse("03/03/2023"), Date.parse("04/03/2023"))

        expect(events.count).to eq(6)

        expect(events.first[:event_id]).to eq(all_day_single_day_event.id)
        expect(events.first[:kind]).to eq("custom_event")
        expect(events.first[:start]).to eq(all_day_single_day_event.start_date.to_fs(:db))
        expect(events.first[:end]).to eq(all_day_single_day_event.end_date.next_day.to_fs(:db))
        expect(events.first[:is_yesterday]).to be(false)

        expect(events.second[:event_id]).to eq(all_day_multiday_event.id)
        expect(events.second[:kind]).to eq("custom_event")
        expect(events.second[:start]).to eq(all_day_multiday_event.start_date.to_fs(:db))
        expect(events.second[:end]).to eq(all_day_multiday_event.end_date.next_day.to_fs(:db))
        expect(events.second[:is_yesterday]).to be(false)

        expect(events.third[:event_id]).to eq(non_all_day_same_day_event.id)
        expect(events.third[:kind]).to eq("custom_event")
        expect(events.third[:start]).to eq(non_all_day_same_day_event.starts_at)
        expect(events.third[:end]).to eq(non_all_day_same_day_event.ends_at)
        expect(events.third[:is_yesterday]).to be(false)

        expect(events.fourth[:event_id]).to eq(non_all_day_multiday_event.id)
        expect(events.fourth[:kind]).to eq("custom_event")
        expect(events.fourth[:start]).to eq(non_all_day_multiday_event.starts_at)
        expect(events.fourth[:end]).to eq(non_all_day_multiday_event.ends_at)
        expect(events.fourth[:is_yesterday]).to be(false)

        # Ordered event
        expect(events.fifth[:start]).to eq(order_tracker_item.ordered_date.to_fs(:db))
        expect(events.fifth[:kind]).to eq("ordered_date")
        expect(events.fifth[:title]).to eq("Ordered: 1 Item")
        expect(events.fifth[:className]).to eq("fc-event-ordered")
        expect(events.fifth[:is_yesterday]).to be(false)

        # Project due date event
        expect(events.last[:start]).to eq(project.due_date.to_fs(:db))
        expect(events.last[:kind]).to eq("project_due_date")
        expect(events.last[:title]).to eq("Due: #{project.name}")
        expect(events.last[:className]).to eq("fc-event-project-due-date")
        expect(events.last[:is_yesterday]).to be(false)
      end
    end

    context "Yesterday events" do
      before { project.update_column(:due_date, Date.current - 1.day) }

      it "returns 6 events" do
        events = project.prepare_calendar_entries(Date.current - 2.days, Date.current + 2.days)

        expect(events.count).to eq(6)

        expect(events.first[:event_id]).to eq(yesterday_event.id)
        expect(events.first[:kind]).to eq("custom_event")
        expect(events.first[:start]).to eq(yesterday_event.start_date.to_fs(:db))
        expect(events.first[:end]).to eq(yesterday_event.end_date.next_day.to_fs(:db))
        expect(events.first[:is_yesterday]).to be(true)

        expect(events.second[:event_id]).to eq(current_day_event.id)
        expect(events.second[:kind]).to eq("custom_event")
        expect(events.second[:start]).to eq(current_day_event.start_date.to_fs(:db))
        expect(events.second[:end]).to eq(current_day_event.end_date.next_day.to_fs(:db))
        expect(events.second[:is_yesterday]).to be(false)

        expect(events.third[:task_id]).to eq(yesterday_task.id)
        expect(events.third[:start]).to eq(yesterday_task.due_date.to_fs(:tb))
        expect(events.third[:kind]).to eq("task_event")
        expect(events.third[:is_yesterday]).to be(true)
        expect(events.third[:is_completed]).to be(true)

        # Yesterday tracker event
        expect(events.fourth[:start]).to eq(order_tracker_item.deliver_date.to_fs(:db))
        expect(events.fourth[:kind]).to eq("deliver_date")
        expect(events.fourth[:title]).to eq("Deliver: 1 Item")
        expect(events.fourth[:className]).to eq("fc-event-deliver")
        expect(events.fourth[:is_yesterday]).to be(true)

        # Currrent day tracker event
        expect(events.fifth[:start]).to eq(order_tracker_item.install_date.to_fs(:db))
        expect(events.fifth[:kind]).to eq("install_date")
        expect(events.fifth[:title]).to eq("Install: 1 Item")
        expect(events.fifth[:className]).to eq("fc-event-install")
        expect(events.fifth[:is_yesterday]).to be(false)

        # Project due date event
        expect(events.last[:start]).to eq(project.due_date.to_fs(:db))
        expect(events.last[:kind]).to eq("project_due_date")
        expect(events.last[:title]).to eq("Due: #{project.name}")
        expect(events.last[:className]).to eq("fc-event-project-due-date")
        expect(events.last[:is_yesterday]).to be(true)
      end
    end
  end
end
