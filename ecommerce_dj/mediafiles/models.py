from django.db import models
import uuid


def generate_uuid():
    return str(uuid.uuid4())[:20]


def upload_to(instance, filename):
    ext = filename.split('.')[-1]
    new_filename = f"{uuid.uuid4().hex}.{ext}"
    return f"uploads/{new_filename}"


class MediaFile(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    file = models.ImageField(upload_to=upload_to)
    original_name = models.CharField(max_length=255, blank=True)
    size = models.IntegerField(default=0)
    mime_type = models.CharField(max_length=100, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'media_files'
        ordering = ['-uploaded_at']

    def __str__(self):
        return self.original_name or self.id
