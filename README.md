# Hyrax COAR Notify
This is designed to implement the [COAR Notify Protocol (v1.0.1)](https://coar-notify.net/specification/1.0.1/)  in [Samvera Hyrax](https://github.com/samvera/hyrax) (v5.2), and support three COAR Notify workflows:

- https://coar-notify.net/catalogue/workflows/pci-sciety/
- https://coar-notify.net/catalogue/workflows/repository-pci/
- https://coar-notify.net/catalogue/workflows/repository-relationship-repository/

It depends on the [COAR-Notify Inbox Rails Engine](https://github.com/antleaf/coar-notify-inbox-rails-engine)

The document [wireframes.pdf](docs/Wireframes.pdf)  created as a part of the design process for Hyrax Notify has the wireframes designs. The images for it are at [Wireframe images](docs/Wireframe images/)

The document [Hyrax Notify with external inbox](docs/Hyrax%20Notify%20with%20external%20inbox.md) details how Hyrax Notify is to be used to send and receive Notify notifications, when configured with an external inbox.



## Running the demonstrator

This is a Hyrax 5.2 app (Ruby 3.3, Rails 7.2, Postgres, Solr 9, Redis) that uses the `hyrax-coar-notify` gem. The COAR Notify inbox is treated as an **external service**: it is not mounted here, and the app talks to it over HTTP.

### Run it with Docker

```bash
cp .env.template.development .env      # set SECRET_KEY_BASE and the COAR_NOTIFY_* values
docker compose up -d --build
```

### Run it on your machine (Rails outside Docker)

```bash
docker compose up -d appdb solr redis   # ports come from .env / docker-compose.yml
bundle install
bin/rails db:create db:migrate
RAILS_ENV=development bin/rails server -p 3000
```

For this mode use `SOLR_HOST=localhost`, `POSTGRES_HOST_APP=localhost` and `REDIS_HOST=localhost` (plus matching ports) in `.env`. Point the `*_PATH` variables at local directories (for example `./storage/uploads/`). Set `VALKYRIE_STORAGE_ADAPTER=versioned_disk_storage` and `HYRAX_ACTIVE_JOB_QUEUE=inline`. When FITS is not installed the app falls back to mime-type-only characterization (`config/initializers/2_local_characterization.rb`).

Create an admin user (the Notify pages need the `admin` role):

```bash
bin/rails runner "
  role = Role.where(name: 'admin').first_or_create!
  user = User.where(email: 'admin@example.com').first_or_initialize
  user.password = 'change-me-please'
  user.save!
  role.users << user unless role.users.include?(user)
"
```

### Configuration

| Variable | Purpose |
|---|---|
| `COAR_NOTIFY_BASE_URL` | Base URL of the external inbox service |
| `COAR_NOTIFY_INBOX_URL` | Where notifications are fetched from (defaults to `<base>/coar_notify_inbox/notifications`) |
| `COAR_NOTIFY_ADMIN_API_TOKEN` | Token used when talking to the inbox |
| `APPLICATION_URL` | Public URL of this app; used to build the work URLs sent in requests |
| `REDIS_URL` or `REDIS_HOST`/`REDIS_PORT` | Redis for Sidekiq, Hyrax locks and Action Cable |

### Try it

1. Sign in and open `/coar_notify`, then **Manage connections**. Add a Notify service whose inbox URL points at the service you want to send requests to.
2. Create a Dataset with a PDF. On its page (as someone who can edit it) use **Request Endorsement** or **Request Review**. A row appears on the Notify dashboard.
3. Notifications from the inbox are fetched by `Hyrax::CoarNotify::FetchNotificationsJob`. Under Sidekiq it runs every five minutes (`config/sidekiq.yml`). To run it once by hand: `bin/rails runner "Hyrax::CoarNotify::FetchNotificationsJob.perform_now"`. An "Announce Endorsement" or "Announce Review" notification is then shown on the work page.

### Where the gem is wired in

| File | Purpose |
|---|---|
| `Gemfile` | The gem, with `require: "hyrax_coar_notify"` (needed because of its two-dash name) |
| `config/routes.rb` | Mounts the engine at `/coar_notify` |
| `app/models/ability.rb` | Who may manage services and open the Notify pages |
| `app/models/dataset.rb`, `app/indexers/dataset_indexer.rb` | `WorkBehavior` and the endorsement/review fields |
| `app/models/solr_document.rb` | Readers for the endorsement/review fields |
| `app/views/hyrax/datasets/show.html.erb` | Renders the request buttons and the endorsements card |
| `config/initializers/pcdm_member_presenter_factory_patch.rb` | Works around a Hyrax 5.2.0 bug that broke pages for works with files |
| `config/initializers/coar_notify_inbox_migration_compat.rb` | Lets `coar_notify_inbox`'s Rails 8.0 migrations run on Rails 7.2 |
