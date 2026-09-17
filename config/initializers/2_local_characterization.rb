# frozen_string_literal: true

# FITS is baked into this app's Docker image at build time (see FITS_PATH/FITS_VERSION build
# args in the Dockerfile) and isn't present when running directly on a host. Fall back to a
# mime-type-only characterizer in that case so file ingest doesn't hard-fail; real Docker-built
# deployments still use Hyrax's default FITS-based characterization.
unless File.executable?(ENV['FITS_PATH'].to_s)
  Rails.application.config.to_prepare do
    Hyrax.config.characterization_service = LocalCharacterizationService
  end
end
