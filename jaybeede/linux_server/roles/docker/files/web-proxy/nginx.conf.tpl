## Nginx handles incoming HTTPS requests and handles ssl termination
events {
	worker_connections 4096;
}
http {
	upstream service-jawanndenn {
		server jawanndenn-ui:80;
	}
	upstream service-etherpad {
		server etherpad-ui:9001;
	}
	# upstream service-virtual-desktop {
	# 	server virtual-desktop-ui:8080;
	# }
	# upstream service-blog {
	# 	server blog-ui:80;
	# }
	# upstream service-limesurvey {
	# 	server limesurvey-ui:80;
	# }
	server {
		listen 80;
		listen [::]:80;
		# server_name {{ server_domain }} www.{{ server_domain }};
		server_name {{ ansible_host }};
		error_log /var/log/nginx/{{ server_domain }}-error.log;
		access_log /var/log/nginx/{{ server_domain }}-access.log;
		server_tokens off;
		# location / {
		# 	proxy_pass http://service-blog;
		# 	proxy_set_header X-Real-IP $remote_addr;
		# 	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		# 	proxy_set_header X-Forwarded-Proto $scheme;
		# 	proxy_set_header X-Forwarded-Port $server_port;
		# 	proxy_set_header Host $host;
		# 	add_header X-XSS-Protection "1; mode=block";
		# 	#add_header Strict-Transport-Security $hsts_header;
		# }
		# location /virtual-desktop {
		# 	proxy_buffering off;
		# 	proxy_pass http://service-virtual-desktop;
		# }
		location /jawanndenn {
		 	rewrite ^(jawanndenn)$ $1/ permanent;
			proxy_pass http://service-jawanndenn;
		}
		location /etherpad/ {
			proxy_pass http://service-etherpad/;
			proxy_set_header Host $host;
			proxy_buffering off;
			proxy_set_header X-Real-IP $remote_addr;
			proxy_set_header Host $host;
			proxy_http_version 1.1;
		}
		# location /limesurvey/ {
		# 	proxy_pass http://service-limesurvey/;
		# 	#proxy_redirect http://$host/ /limesurvey/;
		# 	proxy_set_header Host $host;
		# }
		# location /.well-known/acme-challenge {
		# 	root /var/www;
		# }
		location = /50x.html {
			root /var/www/errors;
		}
		location = /40x.html {
			root /var/www/errors;
		}
	}
}
