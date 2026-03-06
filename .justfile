default:
    echo "Hi"

build:
    kast compile \
        --target js \
        --output target/compiled/main.mjs \
        src/main.ks

build-watch:
    #!/usr/bin/env bash
    just build
    while inotifywait -r -e modify,create,delete,move src; do
        sleep 0.2
        just build
    done

serve:
    just build
    caddy run
