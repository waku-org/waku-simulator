FROM python
WORKDIR /src/app
COPY requirements.txt requirements.txt
COPY traffic.py traffic.py
RUN pip install -r requirements.txt

ENTRYPOINT [ "python",  "./traffic.py" ]
