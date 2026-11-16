from support import Fixture, run, verify_signature
import base64
import gzip
import json
from urllib.parse import parse_qs, unquote, urlsplit

class Handler(Fixture):

    def route(self, body):
        service = verify_signature(self, body)
        target = self.headers.get('X-Amz-Target', '').split('.')[-1]
        self.server.calls[target] = self.server.calls.get(target, 0) + 1
        assert service == 'lambda'
        path = urlsplit(self.path)
        if self.command == 'GET' and path.path.endswith('/functions/'):
            marker = parse_qs(path.query).get('Marker')
            if marker:
                assert marker == ['next+/?']
                result = {'Functions': [{'FunctionName': 'two'}]}
            else:
                result = {'Functions': [{'FunctionName': 'one'}], 'NextMarker': 'next+/?'}
        elif self.command == 'GET':
            assert unquote(path.path) == '/2015-03-31/functions/arn:aws:lambda:us-east-1:123:function:雪'
            result = {'Configuration': {'FunctionName': '雪', 'KMSKeyArn': 'kms', 'CodeSize': 42}}
        elif path.path.endswith('/invocations'):
            assert json.loads(body) == {'hello': '😀'}
            assert self.headers['X-Amz-Invocation-Type'] in ('Event', 'RequestResponse', 'DryRun')
            self.reply(200, '{"errorMessage":"function error"}', {'X-Amz-Function-Error': 'Handled'})
            return
        elif self.command == 'POST':
            data = json.loads(body)
            assert base64.b64decode(data['Code']['ZipFile']) == b'PK\x00\xff'
            assert data['Timeout'] == 5
            result = {}
        else:
            assert self.command == 'DELETE' and (not body)
            result = b''
        self.reply(200, result)
if __name__ == '__main__':
    run(Handler)
