FROM dacut/amazon-linux-python-3.6

ENV APP_HOME /app

RUN yum -y update && yum -y install vim zip
RUN mkdir $APP_HOME
ADD . $APP_HOME

RUN rm -rf $APP_HOME/lib
RUN rm -rf /usr/bin/python
RUN ln -s /usr/bin/python3.6 /usr/bin/python

VOLUME ["$APP_HOME/lib"]
