# frozen_string_literal: true

# Works around a Hyrax 5.2.0 core bug (not related to hyrax-coar-notify):
# Hyrax::PcdmMemberPresenterFactory#query_docs calls
# `Hyrax::SolrService.post(q: query, rows: 10_000)`, passing the query string
# as the `q:` keyword. Hyrax::SolrService#post's signature
# (`query = nil, **args`) only auto-adds `qt: 'standard'` (which routes to the
# defType=lucene handler) when the query is passed positionally - passed as a
# keyword, that injection is silently skipped, so the request falls through
# to the default /select handler (defType=edismax). Solr has ignored `{!...}`
# local params under edismax/dismax by design since 7.2 (a documented
# security hardening, not a Solr bug). Since query_docs builds exactly that
# kind of query (`{!terms f=id}...`), every file-set/member lookup silently
# returns zero results, and callers see `Hyrax::ObjectNotFoundError` for
# documents that plainly exist in the index - this is what was blocking the
# work show page for any work with an attached file.
#
# Patched here by re-adding `qt: 'standard'` explicitly, matching what
# SolrService's own positional-arg call path already does correctly.
Rails.application.config.to_prepare do
  Hyrax::PcdmMemberPresenterFactory.prepend(Module.new do
    private

    def query_docs(generic_type: nil, ids: object.member_ids)
      query = "{!terms f=id}#{ids.join(',')}"
      query += "{!term f=generic_type_si}#{generic_type}" if generic_type
      query += "{!term f=generic_type_sim}#{generic_type}" if generic_type

      Hyrax::SolrService
        .post(q: query, rows: 10_000, qt: 'standard')
        .fetch('response')
        .fetch('docs')
    end
  end)
end
