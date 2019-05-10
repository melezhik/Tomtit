#!/bin/bash

set -e

tom --profile hello@world

tom world
echo LAST
tom --last
echo LAST
