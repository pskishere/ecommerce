import os
import shutil
from django.core.management.base import BaseCommand
from django.conf import settings
from mediafiles.models import MediaFile


class Command(BaseCommand):
    help = 'Seed media files from uploads directory'

    def handle(self, *args, **options):
        upload_dir = settings.MEDIA_ROOT

        # Files that have their original name
        named_files = [
            'banner-1-summer-1710.webp',
            'banner-2-newarrival-1710.webp',
            'banner-3-discount-1710.webp',
            'product-01-watch.webp',
            'product-02-earbuds.webp',
            'product-03-mug.webp',
            'product-04-serum.webp',
            'product-05-sneakers.webp',
            'product-06-wallet.webp',
            'product-07-sunglasses.webp',
            'product-08-plantpot.webp',
            'product-09-notebook.webp',
            'product-10-candle.webp',
            'product-11-tote.webp',
            'product-12-bottle.webp',
            'icon-fashion-01.webp',
            'icon-mens-02.webp',
            'icon-skincare-03.webp',
            'icon-phone-04.webp',
            'icon-home-05.webp',
            'icon-sport-06.webp',
            'icon-food-07.webp',
            'icon-beauty-08.webp',
        ]

        # UUID-named files to rename to original names
        uuid_files = {}
        for root, _, files in os.walk(upload_dir):
            for f in files:
                if not f.endswith('.webp'):
                    continue
                if f in named_files:
                    continue
                parts = f.split('.')
                if len(parts) == 2 and len(parts[0]) == 36:
                    uuid_files[os.path.join(root, f)] = None

        created = 0
        renamed = 0

        # First, rename UUID files to their original names based on a simple mapping
        # We need to figure out which UUID file corresponds to which original name
        # For now, let's just create MediaFile records for named files that exist

        for filename in named_files:
            filepath = self._find_media_file(upload_dir, filename)
            if not os.path.exists(filepath):
                self.stdout.write(f'  Not found: {filename}')
                continue

            mime_type = 'image/png' if filename.endswith('.png') else 'image/webp'
            relative_name = os.path.relpath(filepath, upload_dir)
            media, is_new = MediaFile.objects.get_or_create(
                original_name=filename,
                defaults={
                    'size': os.path.getsize(filepath),
                    'mime_type': mime_type,
                }
            )
            if is_new or media.file.name != relative_name:
                media.file.name = relative_name
                media.size = os.path.getsize(filepath)
                media.mime_type = mime_type
                media.save()
                if is_new:
                    created += 1
                    self.stdout.write(f'  Created: {filename}')
                else:
                    self.stdout.write(f'  Updated path: {filename}')

        self.stdout.write(self.style.SUCCESS(f'\nCreated {created} media files'))

    def _find_media_file(self, upload_dir, filename):
        for path in (
            os.path.join(upload_dir, filename),
            os.path.join(upload_dir, 'uploads', filename),
        ):
            if os.path.exists(path):
                return path
        return os.path.join(upload_dir, filename)
