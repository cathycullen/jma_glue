# JMA Glue

This app is a small glue app that helps connect existing sites like JMA and CareerCheetah to services like Podio and ConstantContact.

## Setup the app

```
bundle install
```

## Run the app

```
shotgun
```

## Access the app

For now you can easily access the two endpoints `http://localhost:9393/constant_contact` and `http://localhost:9393/podio_contact` in your browser with GET requests. These will switch to POST requests once we deploy and actually accept input from form on the JMA or CareerCheetah site.

## Adding support for APIs

All API keys should be set in your local `.env` file. All variables in the `.env` file will be available inside the app via the global `ENV`. Here's an example `.env`:

```
CONSTANT_CONTACT_API_KEY=94859432573956438965387563
PODIO_API_KEY=213567254230487234
```

You'd then have access to these keys inside the app like so:

```
ENV['CONSTANT_CONTACT_API_KEY']
ENV['PODIO_API_KEY']
```
