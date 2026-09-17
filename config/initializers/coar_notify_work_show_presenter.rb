# frozen_string_literal: true

# hyrax-coar-notify's install generator does not wire its WorkBehavior/
# WorkShowPresenterBehavior concerns into the host app - each work model and
# its show presenter must include them manually. Dataset includes
# Hyrax::CoarNotify::WorkBehavior directly (see app/models/dataset.rb); the
# show presenter is Hyrax's shared Hyrax::WorkShowPresenter (used by every
# work type), so it's extended here via to_prepare rather than reopening the
# class directly, which Zeitwerk would reject as an autoload path mismatch.
Rails.application.config.to_prepare do
  Hyrax::WorkShowPresenter.include(Hyrax::CoarNotify::WorkShowPresenterBehavior)
end
