FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive

# ubuntu setup
RUN apt-get update -y
RUN apt-get upgrade -y 

RUN apt-get install -y software-properties-common
RUN apt-get update

RUN apt-get install --yes --no-install-recommends \
		apt-utils ipcalc tzdata net-tools mariadb-client \
		libmysqlclient-dev unzip wget cron coreutils nano \
        freeradius freeradius-mysql freeradius-utils openssl \
		language-pack-en \
	&& rm -rf /var/lib/apt/lists/*

# RUN apt-get install --yes --no-install-recommends  lsof

ENV DEBIAN_FRONTEND teletype

# /data should be mounted as volume to avoid recreation of database entries
RUN mkdir /app /data /internal_data

# setup working directory
WORKDIR /app

# RUN service freeradius stop
# RUN freeradius -X -i 0.0.0.0 -p 1850

# Copy init script to image
ADD ./init-freeradius.sh /app

# Make init.sh script executable
RUN chmod +x /app/init-freeradius.sh

# Expose FreeRADIUS Ports
EXPOSE ${PORT_1} ${PORT_2}

# Run the script which executes freeradius in foreground
CMD ["/app/init-freeradius.sh"]
# ENTRYPOINT ["/app/init-freeradius.sh"]