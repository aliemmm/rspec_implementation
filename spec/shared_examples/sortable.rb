RSpec.shared_examples_for("sortable") do
  before do
    item.save!

    allow(item).to receive(:ensure_sort_order)

    item.save!
  end

  it "ensure sort order is executed" do
    expect(item).to have_received(:ensure_sort_order).with(items_relation).once
  end
end
