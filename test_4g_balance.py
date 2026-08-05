import urllib.request
import urllib.parse
import ssl
import re

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

headers_base = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
}

url = 'https://ptc.gov.ye/?page_id=9017'
req = urllib.request.Request(url, headers=headers_base)

try:
    with urllib.request.urlopen(req, context=ctx, timeout=15) as resp:
        html = resp.read().decode('utf-8', errors='ignore')
        cookies = resp.headers.get('Set-Cookie')
        if cookies:
            cookies = cookies.split(';')[0]
        else:
            cookies = ''
            
        nonce_match = re.search(r'qb4g_nonce_field"\s+value="([^"]+)', html)
        nonce = nonce_match.group(1) if nonce_match else ''
        
        print("Nonce:", nonce)
        print("Cookies:", cookies)
        
        # Test 1: Empty Captcha
        print("\n--- Test 1: Empty Captcha ---")
        payload = {
            'qb4g_nonce_field': nonce,
            '_wp_http_referer': '/?page_id=9017',
            'qb4g_submit': 'YES',
            'phone4gidnew': '101750466',
            'captcha_code_q4Gbill': '',
            'qsubmitnew': 'استعلام',
        }
        encoded = urllib.parse.urlencode(payload).encode('utf-8')
        req_post = urllib.request.Request(
            url, 
            data=encoded, 
            headers={**headers_base, 'Cookie': cookies, 'Content-Type': 'application/x-www-form-urlencoded'}
        )
        with urllib.request.urlopen(req_post, context=ctx, timeout=15) as resp_post:
            res_html = resp_post.read().decode('utf-8', errors='ignore')
            if 'transdetail' in res_html:
                print("SUCCESS: Balance table found with empty captcha!")
            elif 'رمز التحقق' in res_html or 'captcha' in res_html.lower():
                print("FAILED: Server rejected empty captcha.")
                # print snippet of error
                err = re.search(r'<div[^>]*color:red[^>]*>(.*?)</div>', res_html)
                if err:
                    print("Error msg:", err.group(1))
            else:
                print("FAILED: Unknown response. Length:", len(res_html))

        # Test 2: Dummy Captcha
        print("\n--- Test 2: Dummy Captcha '1234' ---")
        payload['captcha_code_q4Gbill'] = '1234'
        encoded2 = urllib.parse.urlencode(payload).encode('utf-8')
        req_post2 = urllib.request.Request(
            url, 
            data=encoded2, 
            headers={**headers_base, 'Cookie': cookies, 'Content-Type': 'application/x-www-form-urlencoded'}
        )
        with urllib.request.urlopen(req_post2, context=ctx, timeout=15) as resp_post2:
            res_html2 = resp_post2.read().decode('utf-8', errors='ignore')
            if 'transdetail' in res_html2:
                print("SUCCESS: Balance table found with dummy captcha!")
            elif 'رمز التحقق' in res_html2 or 'captcha' in res_html2.lower():
                print("FAILED: Server rejected dummy captcha.")
            else:
                print("FAILED: Unknown response.")

except Exception as e:
    print("Error:", e)
