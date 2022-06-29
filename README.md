# Brewdog Beer Browser

Elm application that allows the user to explore the Brewdog beer catalogue.

## Running in development
This application is scaffolded with the help of [`create-elm-app`](https://github.com/halfzebra/create-elm-app).

In order to run a development server locally, just run

```
npm i && npm start
```

## Building for production

```
npm i && npm run build
```

## Future development

The application leaves some things wanting. Here is a list of possible future improvements.

* Add debounce time for when the user types a search query, so that we minimize the number of API calls.
* Add proper error handling to make development easier and so that the user can understand what went wrong.
* The API that the app consumes is not great when it comes to pagination. As of now, we might show a "next page" button even though there's no next page. If the total number of matches were known, it would not be a problem.
* Move code for basic styling, such as padding, spacing and colors to its own module.    
