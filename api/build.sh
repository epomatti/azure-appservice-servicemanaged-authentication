#!/bin/bash

rm ./bin/api.zip
dotnet publish --configuration Release --output ./bin/publish
cd ./bin/publish
zip -r -q ../api.zip .
