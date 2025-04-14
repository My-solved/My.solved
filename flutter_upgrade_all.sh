#!/bin/bash
find . -name "pubspec.yaml" -execdir flutter pub upgrade \;
