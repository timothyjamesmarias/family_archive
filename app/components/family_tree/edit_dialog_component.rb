module FamilyTree
  # What every edit form shares inside the dialog's frame: the heading and
  # any error above the caller's content. Forms inside submit to the same
  # frame, so a 422 lands back here with the error shown.
  class EditDialogComponent < ApplicationComponent
    def initialize(heading:, error: nil)
      @heading = heading
      @error = error
    end
  end
end
