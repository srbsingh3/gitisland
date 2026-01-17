#!/usr/bin/env python3
"""
Fetch GitHub contribution data from public profile page
Usage: python3 fetch_github_contributions.py srbsingh3
"""

import sys
import json
import re
import ssl
from urllib.request import Request, urlopen
from datetime import datetime

def fetch_contributions(username):
    url = f"https://github.com/{username}"

    # Add headers to mimic a browser
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    }

    request = Request(url, headers=headers)

    # Create SSL context that doesn't verify certificates
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    try:
        with urlopen(request, context=ctx) as response:
            html = response.read().decode('utf-8')

        # Save HTML for debugging
        # with open('debug.html', 'w') as f:
        #     f.write(html)

        # Find the contribution data in the SVG
        # Look for the data-level and data-date attributes
        pattern = r'data-date="([^"]+)"[^>]*?data-level="([^"]+)"'
        matches = re.findall(pattern, html, re.DOTALL)

        if not matches:
            # Try alternative pattern
            pattern = r'data-level="([^"]+)"[^>]*?data-date="([^"]+)"'
            matches = [(date, level) for level, date in re.findall(pattern, html, re.DOTALL)]

        if not matches:
            # Try finding tool-tip data
            pattern = r'data-date="([^"]+)".*?(\d+)\s+contribution'
            tooltip_matches = re.findall(pattern, html, re.DOTALL)
            if tooltip_matches:
                matches = [(date, str(min(4, count // 3 if count else 0))) for date, count in tooltip_matches]

        if not matches:
            print("Could not find contribution data in HTML")
            print("Trying to find any contribution-related data...")
            # Look for any data-date attributes
            dates = re.findall(r'data-date="([^"]+)"', html)
            print(f"Found {len(dates)} data-date attributes")
            return None

        # Get last 22 weeks (154 days)
        contributions = []
        for date_str, level in matches[-154:]:
            contributions.append({
                'date': date_str,
                'level': int(level),
                'count': int(level) * 3  # Approximate count from level
            })

        # Calculate total (approximate)
        total = sum(c['count'] for c in contributions)

        # Group by weeks
        weeks = []
        current_week = []

        for contrib in contributions:
            current_week.append(contrib)
            date_obj = datetime.fromisoformat(contrib['date'])
            if date_obj.weekday() == 6:  # Sunday
                weeks.append(current_week)
                current_week = []

        if current_week:
            weeks.append(current_week)

        return {
            'username': username,
            'total': total,
            'weeks': weeks
        }

    except Exception as e:
        print(f"Error fetching data: {e}")
        return None

if __name__ == "__main__":
    username = sys.argv[1] if len(sys.argv) > 1 else "srbsingh3"

    print(f"Fetching contribution data for {username}...")
    data = fetch_contributions(username)

    if data:
        print(f"\nFound {len(data['weeks'])} weeks of data")
        print(f"Total contributions (approx): {data['total']}")
        print(f"\nSwift code to hardcode:\n")
        print("// Paste this into GitHubService.swift generateMockData()")
        print(json.dumps(data, indent=2))
