import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { startTime: String, endTime: String };

  connect() {
    this.render();
  }

  render() {
    const startTime = new Date(this.startTimeValue);
    const endTime = new Date(this.endTimeValue);

    const startMonth = startTime.getMonth();
    const endMonth = endTime.getMonth();

    const calendarComponent = document.createElement("div");
    calendarComponent.classList.add(
      ...[
        "datepicker-picker",
        "inline-flex",
        "gap-2",
        "rounded-lg",
        "bg-white",
        "dark:bg-gray-700",
        "p-4",
      ],
    );

    if (startMonth == endMonth) {
      calendarComponent.append(this.renderMonth(startTime, startTime, endTime));
    } else {
      const endOfStartMonth = new Date(
        startTime.getFullYear(),
        startTime.getMonth() + 1,
        0,
      );
      const startOfEndMonth = new Date(
        endTime.getFullYear(),
        endTime.getMonth(),
        1,
      );

      calendarComponent.append(
        this.renderMonth(startTime, startTime, endTime),
        this.renderMonth(startOfEndMonth, startTime, endTime),
      );
    }
    this.element.replaceChildren(calendarComponent);
  }

  isWithinSelection(date, startSelection, endSelection) {
    const isSameMonth = startSelection.getMonth() === endSelection.getMonth();

    if (isSameMonth) {
      return (
        startSelection.getDate() <= date.getDate() &&
        date.getDate() <= endSelection.getDate() &&
        date.getMonth() === startSelection.getMonth()
      );
    }

    const inStartMonthRange =
      date.getMonth() === startSelection.getMonth() &&
      date.getDate() >= startSelection.getDate();

    const inEndMonthRange =
      date.getMonth() === endSelection.getMonth() &&
      date.getDate() <= endSelection.getDate();

    return inStartMonthRange || inEndMonthRange;
  }

  // Returns a single week array, given the start day and relevant month/year information
  renderWeek(startDate, currentMonth, year, startSelection, endSelection) {
    const week = document.createDocumentFragment();
    let date = new Date(year, currentMonth, startDate);

    // Fill the week starting from the given day
    for (let i = 0; i < 7; i++) {
      const day = document.createElement("span");
      if (date.getMonth() !== currentMonth) {
        day.classList.add(...this.offMonthStyle());
      } else {
        day.classList.add(...this.inMonthStyle());
      }
      if (this.isWithinSelection(date, startSelection, endSelection)) {
        day.classList.add(...this.selectedStyle());
        if (
          startSelection.getDate() == date.getDate() &&
          startSelection.getMonth() == date.getMonth()
        ) {
          day.classList.add("rounded-s-lg");
        }
        if (
          endSelection.getDate() == date.getDate() &&
          endSelection.getMonth() == date.getMonth()
        ) {
          day.classList.add("rounded-e-lg");
        }
        if (date.getMonth() !== currentMonth) {
          day.classList.remove(
            ...[
              "bg-blue-700",
              "!bg-primary-700",
              "dark:bg-blue-600",
              "dark:!bg-primary-600",
            ],
          );
          day.classList.add(
            ...[
              "bg-blue-300",
              "!bg-primary-300",
              "dark:bg-blue-900",
              "dark:!bg-primary-900",
            ],
          );
        }
      }

      // date.getDate() <= endSelection.getDate()

      day.textContent = date.getDate();
      week.appendChild(day);
      date.setDate(date.getDate() + 1); // Move to the next day
    }

    return week;
  }

  // Returns the 6-week calendar structure for the given date
  renderMonth(monthStartDate, startDate, endDate) {
    const year = monthStartDate.getFullYear();
    const month = monthStartDate.getMonth(); // 0-based index (October = 9)

    const firstDayOfMonth = new Date(year, month, 1);
    const firstWeekdayOfMonth = firstDayOfMonth.getDay(); // 0 = Sunday, 6 = Saturday
    let startDay = 1 - firstWeekdayOfMonth; // Start the first week with previous month's days

    const calendar = document.createElement("div");
    const monthHeader = document.createElement("div");
    monthHeader.classList.add(...["datepicker-header"]);
    const monthHeaderWrapper = document.createElement("div");
    monthHeaderWrapper.classList.add(
      ...["datepicker-controls", "flex", "justify-center", "mb-2"],
    );
    const monthHeaderText = document.createElement("div");
    monthHeaderText.classList.add(
      ...[
        "text-sm",
        "rounded-lg",
        "text-gray-900",
        "dark:text-white",
        "bg-white",
        "dark:bg-gray-700",
        "font-semibold",
        "py-2.5",
        "px-5",
        "view-switch",
      ],
    );
    monthHeaderText.textContent = monthStartDate.toLocaleString(undefined, {
      year: "numeric",
      month: "long",
    });
    monthHeader.appendChild(monthHeaderWrapper);
    monthHeaderWrapper.appendChild(monthHeaderText);
    const monthMain = document.createElement("div");
    monthMain.classList.add(...["datepicker-main", "p-1"]);
    const monthMainWrapper = document.createElement("div");
    monthMainWrapper.classList.add(...["datepicker-view", "flex"]);
    monthMain.appendChild(monthMainWrapper);
    const daysWrapper = document.createElement("div");
    monthMainWrapper.appendChild(daysWrapper);
    daysWrapper.classList.add(...["days"]);
    const daysHeader = document.createElement("div");
    daysWrapper.appendChild(daysHeader);
    daysHeader.classList.add(
      ...["days-of-week", "grid", "grid-cols-7", "mb-1"],
    );
    const weekDay = new Date(
      firstDayOfMonth.getFullYear(),
      firstDayOfMonth.getMonth(),
      startDay,
    );
    for (let d = 0; d < 7; d++) {
      const weekElement = document.createElement("span");
      weekElement.textContent = weekDay.toLocaleString(undefined, {
        weekday: "short",
      });
      weekElement.classList.add(
        ...[
          "dow",
          "text-center",
          "h-6",
          "leading-6",
          "text-sm",
          "font-medium",
          "text-gray-500",
          "dark:text-gray-400",
        ],
      );
      daysHeader.appendChild(weekElement);
      weekDay.setDate(weekDay.getDate() + 1);
    }
    const daysGrid = document.createElement("div");
    daysGrid.classList.add(...["w-64", "grid", "grid-cols-7"]);
    daysWrapper.appendChild(daysGrid);
    // Add weeks until the month ends
    for (let i = 0; i < 6; i++) {
      daysGrid.appendChild(
        this.renderWeek(startDay, month, year, startDate, endDate),
      );
      startDay += 7;
    }
    calendar.append(monthHeader, monthMain);
    return calendar;
  }

  offMonthStyle() {
    return [
      "datepicker-cell",
      "block",
      "flex-1",
      "leading-9",
      "border-0",
      "text-center",
      "font-semibold",
      "text-sm",
      "day",
      "prev",
      "text-gray-500",
      "disabled",
      "text-gray-400",
      "dark:text-gray-500",
    ];
  }

  inMonthStyle() {
    return [
      "datepicker-cell",
      "block",
      "flex-1",
      "leading-9",
      "border-0",
      "text-center",
      "text-gray-900",
      "dark:text-white",
      "font-semibold",
      "text-sm",
      "day",
    ];
  }

  selectedStyle() {
    return [
      "datepicker-cell",
      "block",
      "flex-1",
      "leading-9",
      "border-0",
      "text-center",
      "font-semibold",
      "text-sm",
      "day",
      "selected",
      "bg-blue-700",
      "!bg-primary-700",
      "text-white",
      "dark:bg-blue-600",
      "dark:!bg-primary-600",
      "focused",
    ];
  }
}
