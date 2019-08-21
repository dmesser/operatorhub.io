FROM registry.access.redhat.com/ubi8/python-36 as python-build

ARG COURIER_VERSION=2.1.0
ARG OPERATORS_REPO=https://github.com/operator-framework/community-operators
ARG OPERATORS_BRANCH=master

RUN pip install operator-courier==$COURIER_VERSION

RUN git clone -b $OPERATORS_BRANCH $OPERATORS_REPO /tmp/community-operators

RUN cd /tmp/community-operators/upstream-community-operators \
    && find . -mindepth 1 -maxdepth 1 -type d -exec echo "courier-operator -> {}" \; -exec operator-courier nest {} nested-structure/{} \;  \
    && echo "Done"

FROM registry.access.redhat.com/ubi8/nodejs-10:latest as node-frontend-build
WORKDIR /opt/app-root/src

COPY frontend/package.json .
RUN npm install

COPY frontend/ /opt/app-root/src/
RUN npm run-script build

FROM registry.access.redhat.com/ubi8/nodejs-10:latest as node-server-build
WORKDIR /opt/app-root/src

COPY server/package.json .
RUN npm install

COPY server/ /opt/app-root/src

FROM registry.access.redhat.com/ubi8/nodejs-10:latest
WORKDIR /opt/app-root/src/server

ENTRYPOINT [ "node" ]
EXPOSE 8080
CMD [ "/opt/app-root/src/server/server.js" ]

COPY --from=node-frontend-build /opt/app-root/src/ /opt/app-root/src/frontend
COPY --from=node-server-build /opt/app-root/src/ /opt/app-root/src/server
COPY --from=python-build /tmp/community-operators /opt/app-root/src/server/data/community-operators