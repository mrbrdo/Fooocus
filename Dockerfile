FROM nvidia/cuda:12.3.1-base-ubuntu22.04
ENV DEBIAN_FRONTEND noninteractive
ENV CMDARGS --listen

RUN echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" >> /etc/apt/sources.list && \
	echo "deb-src https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" >> /etc/apt/sources.list &&\
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 

# we are stuck with python 3.11 due to torch 2.1.0
RUN apt-get update -y && \
	apt-get install -y curl libgl1 libglib2.0-0 git python3.11 python3.11-dev python3.11-distutils && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# symlink to run in the correct version
RUN ln -s /usr/bin/python3.11 /usr/bin/python 
# install pip
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
	python3.11 get-pip.py && \
	rm get-pip.py

COPY requirements_docker.txt requirements_versions.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements_docker.txt -r /tmp/requirements_versions.txt && \
	rm -f /tmp/requirements_docker.txt /tmp/requirements_versions.txt
RUN pip install --no-cache-dir xformers==0.0.23 --no-dependencies
RUN curl -fsL -o /usr/local/lib/python3.11/dist-packages/gradio/frpc_linux_amd64_v0.2 https://cdn-media.huggingface.co/frpc-gradio-0.2/frpc_linux_amd64 && \
	chmod +x /usr/local/lib/python3.11/dist-packages/gradio/frpc_linux_amd64_v0.2

RUN adduser --disabled-password --gecos '' user && \
	mkdir -p /content/app /content/data

COPY entrypoint.sh /content/
RUN chown -R user:user /content

WORKDIR /content
USER user

COPY --chown=user:user . /content/app
RUN mv /content/app/models /content/app/models.org

CMD [ "sh", "-c", "/content/entrypoint.sh ${CMDARGS}" ]
