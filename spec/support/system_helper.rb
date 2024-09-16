module SystemHelper
  # Useful for testing recurring elements such as table rows, technically bypasses all the arguments to
  # #find_all for finding an elements, except the block which is bypassed to #within.
  # Then yields each found element wrapped in #withing block for you.
  #
  # Also provides rspec expectation to find at least one of those elements.
  #
  # @example
  #   within_each("tbody tr") do |row|
  #     expect(row).to have_link("Update")
  #     expect(row).to have_link("Delete")
  #   end
  #
  # @see Capybara::Node::Finders#all
  # @see Capybara::Session#within
  def within_each(*args, **opts, &)
    elements = find_all(*args, **opts)
    expect(elements.size).not_to eq(0)
    elements.each { |element| within(element, &) }
  end
end
