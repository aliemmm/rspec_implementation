RSpec.describe CalendarEvent do
  let(:calendar_event) { build(:calendar_event, project:, all_day: false) }
  let(:project) { build(:project, designers: [designer], created_by: designer) }
  let(:designer) { build(:user, :designer, team:) }
  let(:team) { build(:team) }

  it { is_expected.to respond_to(:team) }

  context "is valid" do
    it "when end date is greater than start date" do
      calendar_event.ends_at = 1.day.from_now

      expect(calendar_event).to be_valid
    end

    it "when end date is equal to start_date" do
      expect(calendar_event).to be_valid
    end
  end

  context "is invalid" do
    it "when end date in terms of date is earlier than start date" do
      calendar_event.ends_at = 2.days.ago

      expect(calendar_event).not_to be_valid
      expect(calendar_event.errors.full_messages).to include("Ends at can't be earlier than the Start date")
    end

    it "when end date in terms of time is less than start date" do
      calendar_event.ends_at = 1.hour.ago

      expect(calendar_event).not_to be_valid
      expect(calendar_event.errors.full_messages).to include("Ends at can't be earlier than the Start time")
    end
  end
end
