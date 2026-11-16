# frozen_string_literal: true

# Lightweight stand-in for Hyrax::Characterization::ValkyrieCharacterizationService, used only
# when FITS isn't available (e.g. running the app directly on a host instead of the Docker
# image, which bakes FITS in at build time). Only extracts the mime type (via Marcel, bundled
# with Rails) instead of running full FITS characterization.
#
# Deliberately does not publish 'file.characterized' - Hyrax::Listeners::FileListener reacts to
# that by enqueuing derivative (thumbnail) generation via hydra-derivatives, which needs
# libvips (also not available on a bare host). Derivatives aren't needed to test the
# request-endorsement/review flow, so that step is skipped here rather than faked.
class LocalCharacterizationService
  def self.run(metadata:, file:, user: ::User.system_user, **_options)
    file.rewind
    content = file.read
    metadata.mime_type = Marcel::MimeType.for(StringIO.new(content), name: metadata.original_filename.to_s)

    saved = Hyrax.persister.save(resource: metadata)
    Hyrax.publisher.publish('file.metadata.updated', metadata: saved, user: user)
  end
end
