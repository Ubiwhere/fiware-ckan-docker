FROM python:2.7

WORKDIR /usr/lib/ckan/default

ADD ./ckan/entrypoint.sh /

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -qqy \
	&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
	git-core nginx supervisor expect \
	&& pip install uwsgi \
	&& pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.7.3#egg=ckan' \
	&& pip install -r src/ckan/requirements.txt \
	&& pip install -e git+https://github.com/conwetlab/ckanext-datarequests.git#egg=ckanext-datarequests \
	&& pip install -e git+https://github.com/ckan/ckanext-geoview.git#egg=ckanext-geoview \
	&& pip install -e git+https://github.com/telefonicaid/ckanext-ngsiview#egg=ckanext-ngsiview \
	&& pip install -e git+https://github.com/conwetlab/ckanext-oauth2#egg=ckanext-oauth2 \
	&& pip install -e git+https://github.com/ckan/ckanext-pdfview.git#egg=ckanext-pdfview \
	&& pip install -e git+https://github.com/conwetlab/ckanext-privatedatasets.git#egg=ckanext-privatedatasets \
	&& pip install -e git+https://github.com/conwetlab/ckanext-storepublisher.git#egg=ckanext-storepublisher \
	&& mkdir -p /etc/ckan/default/ \
	&& cp src/ckan/ckan/config/who.ini /etc/ckan/default/ \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& rm -fr /etc/nginx/sites-* \
	&& chmod a+x /entrypoint.sh \
	&& DEBIAN_FRONTEND=noninteractive apt-get remove -y git-core \
	&& DEBIAN_FRONTEND=noninteractive apt-get --purge autoremove -y \
	&& rm -fr /var/apt/lists/*

ADD ./ckan/nginx.conf /etc/nginx/conf.d/
ADD ./ckan/uwsgi.ini /etc/uwsgi/
ADD ./ckan/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD ./ckan/ckan.py /etc/ckan/default/

EXPOSE 80 443

VOLUME ["/etc/ckan/default"]
VOLUME ["/var/lib/ckan"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]