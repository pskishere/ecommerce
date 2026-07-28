from django.db import migrations, models
import mediafiles.models


class Migration(migrations.Migration):

    dependencies = [
        ('mediafiles', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='mediafile',
            name='file',
            field=models.FileField(upload_to=mediafiles.models.upload_to),
        ),
    ]
