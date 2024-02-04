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
	upstream service-virtual-desktop {
		server virtual-desktop-ui:8080;
	}
	upstream service-blog {
		server blog-ui:80;
	}
	upstream service-limesurvey {
		server limesurvey-ui:80;
	}
	server {
		listen 80;
		listen [::]:80;
		server_name {{ server_domain }} www.{{ server_domain }};
{% if https_flag == 1 %}
		return 301 https://$server_name$request_uri;
	}
	server {
		listen 443 ssl http2;
		listen [::]:443 ssl http2;
		server_name {{ server_domain }} www.{{ server_domain }};
		ssl_certificate /etc/nginx/ssl/{{ server_domain }}/fullchain.pem;
		ssl_certificate_key /etc/nginx/ssl/{{ server_domain }}/privkey.pem;
		ssl_protocols TLSv1.3 TLSv1.2;
		ssl_ciphers "HIGH:!aNULL:!MD5";
		ssl_session_cache shared:SSL:10m;
		ssl_session_timeout 10m;
		ssl_prefer_server_ciphers on;
		ssl_dhparam /etc/nginx/ssl/{{ server_domain }}/dhparam2048.pem;
		ssl_session_tickets off;
		ssl_stapling on;
		ssl_stapling_verify on;
		resolver {{ network_dns }} {{ network_dns2 }} valid=300s;
		resolver_timeout 10s;
{% endif %}
		server_tokens off;
		location / {
			proxy_pass http://service-blog;
			proxy_set_header X-Real-IP $remote_addr;
			proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto $scheme;
			proxy_set_header X-Forwarded-Port $server_port;
			proxy_set_header Host $host;
			add_header X-XSS-Protection "1; mode=block";
			add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
		}
		location /virtual-desktop {
			proxy_buffering off;
			proxy_pass http://service-virtual-desktop;
		}
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
		location /limesurvey/ {
			proxy_pass http://service-limesurvey/;
			proxy_set_header Host $host;
		}
{% if acmechallenge_flag == 1 %}
		location /.well-known/acme-challenge {
			default_type "text/plain";
			root         /var/www/html/;
		}
{% endif %}
		location = /50x.html {
			root /var/www/errors;
		}
		location = /40x.html {
			root /var/www/errors;
		}
	}
}
