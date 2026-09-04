module ApplicationHelper
  def specialty_options(selected)
    options_for_select(Practitioner::SPECIALTIES.map { |s| [s.humanize, s] }, selected)
  end

  def slot_label(time)
    return "No slot this week" if time.nil?
    day = if time.to_date == Time.zone.tomorrow then "Tomorrow" else time.strftime("%a %-d %b") end
    "#{day}, #{time.strftime('%H:%M')}"
  end

  def euro(amount)
    number_to_currency(amount, unit: "EUR", precision: 0, format: "%n %u")
  end
end
