# Admin For YouPin
[![YouPin (ยุพิน)](https://raw.githubusercontent.com/youpin-city/youpin-web-admin/master/public/img/logo.png)](http://youpin.city)

This is admin application for YouPin open reporting platform.

## Run normally

Once started, it restarts automatically on changes in `src/lib/*`.

```
$ npm install
$ npm start

# Server now listens on default port 8080
```

## Run with Docker


Or even better, use docker and leave no traces on your machine.

```
$ docker-compose up
```

To make development easier, we made some files and directories live-reloading. This can be configured in `docker-compose.yml` under __web.volumes__.

#### Note: 

Please note that `./node_modules/` directory cannot be live-reloading. This is because some dependencies are OS-specific binaries (e.g. __node-sass__). If environment on host machine and Docker are different, these binaries cannot be shared (e.g. darwin vs linux). So when you updated dependencies in __package.json__ via `npm install`, you need to rebuild docker container by:

```
$ docker-compose build
```


To inspect current state of Docker machine, you can do:

```
# Show current directory
$ docker-compose run --rm web pwd

# Display node version
$ docker-compose run --rm web node -v
```

## Development

Run watch to rebuild assets on changes in `src/assets/*`.

```
$ npm run watch
```

Test, lint and build before commit.

```
$ npm run build
```

## Linting

For linting to work on text editor, you may need to install eslint globally:

```
$ npm install eslint -g
```

### Sublime Text 3

Install the following packages to aid linting:

- SublimeLinter
- SublimeLinter-contrib-eslint

## Changelog

__0.1.0__

- Initial release

## License

Copyright (c) 2016

Licensed under the [MIT license](LICENSE).
