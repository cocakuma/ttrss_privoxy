FROM python:2.7.16-alpine3.9
LABEL maintainer="imfuego@gmail.com"

WORKDIR /ttrss_privoxy

VOLUME /ttrss_privoxy

COPY privoxy.conf proxychains.conf update_gfwlist.sh ./

RUN apk add --no-cache privoxy && \
	apk add --no-cache proxychains-ng && \
	pip install gfwlist2privoxy && \
	wget -O /tmp/gfwlist.txt https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt && \
	gfwlist2privoxy -i /tmp/gfwlist.txt -f /etc/privoxy/gfw.action -p 127.0.0.1:1080 -t socks5 && \
	rm -f /tmp/gfwlist.txt && \
	echo "26 03 * * * sh /ttrss_privoxy/update_gfwlist.sh > /var/log/update_gfwlist.log 2>&1" >> /etc/crontab

CMD privoxy --no-daemon /ttrss_privoxy/privoxy.conf