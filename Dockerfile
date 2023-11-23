FROM debian:bookworm-slim
RUN apt update && apt install curl wget file -y

COPY makemkv_create.sh /makemkv_create.sh
RUN chmod +x /makemkv_create.sh
CMD /makemkv_create.sh
