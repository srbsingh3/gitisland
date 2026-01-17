#!/usr/bin/env python3
"""
Fetch GitHub contribution data using GitHub's API
Usage: python3 fetch_github_contributions_api.py srbsingh3
"""

import sys
import json
from urllib.request import Request, urlopen
from datetime import datetime, timedelta
import ssl

def fetch_contributions(username):
    # GitHub's public contribution calendar endpoint
    url = f"https://github-contributions-api.jogruber.de/v4/{username}?y=last"

    # Create SSL context
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    }

    request = Request(url, headers=headers)

    try:
        with urlopen(request, context=ctx) as response:
            data = json.loads(response.read().decode('utf-8'))

        # Get all contributions
        all_contributions = []
        if 'contributions' in data:
            for contrib in data['contributions']:
                all_contributions.append({
                    'date': contrib['date'],
                    'count': contrib['count'],
                    'level': contrib['level']
                })

        # Get last 22 weeks (154 days)
        all_contributions = all_contributions[-154:]

        # Calculate total
        total = sum(c['count'] for c in all_contributions)

        # Group by weeks (Sunday to Saturday)
        weeks = []
        current_week = []

        for contrib in all_contributions:
            date_obj = datetime.fromisoformat(contrib['date'])
            current_week.append(contrib)

            # End week on Saturday (weekday 5)
            if date_obj.weekday() == 5:
                weeks.append(current_week)
                current_week = []

        # Add remaining days
        if current_week:
            weeks.append(current_week)

        return {
            'username': username,
            'total': total,
            'weeks': weeks
        }

    except Exception as e:
        print(f"Error fetching data: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    username = sys.argv[1] if len(sys.argv) > 1 else "srbsingh3"

    print(f"Fetching contribution data for {username}...")
    data = fetch_contributions(username)

    if data:
        print(f"\nFound {len(data['weeks'])} weeks of data")
        print(f"Total contributions: {data['total']}")
        print(f"\nJSON data:\n")
        print(json.dumps(data, indent=2))
