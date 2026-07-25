from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion

import backend.models


class Migration(migrations.Migration):

    dependencies = [
        ('backend', '0008_order_fulfillment_after_sale'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='BrowseHistory',
            fields=[
                ('id', models.CharField(default=backend.models.generate_uuid, max_length=50, primary_key=True, serialize=False)),
                ('viewed_at', models.DateTimeField(auto_now=True)),
                ('product', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='browse_histories', to='backend.product')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='browse_histories', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'browse_histories',
                'ordering': ['-viewed_at'],
                'unique_together': {('user', 'product')},
            },
        ),
    ]
