#!/bin/env bash

ls -d $1/*/ | while read d; do if [[ -d "$d".git ]]; then git -C $d status && git -C $d fetch -p && git -C $d pull; fi; done
