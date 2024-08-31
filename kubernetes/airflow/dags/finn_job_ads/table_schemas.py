from sqlalchemy.orm import DeclarativeBase, mapped_column, Mapped
from typing import Optional
from datetime import datetime


from finn_ingestion_lib import get_ingestion_db_sqlalchemy_engine

class Base(DeclarativeBase):
    pass

class FinnJobAdsMetadata(Base):
    __tablename__ = "finn_job_ads__metadata"

    # should make id a primary key
    id: Mapped[int] = mapped_column(primary_key=True)
    type: Mapped[str]
    main_search_key: Mapped[str]
    heading: Mapped[str]
    location: Mapped[Optional[str]]
    timestamp: Mapped[datetime]
    ad_type: Mapped[int]
    canonical_url: Mapped[str]
    job_title: Mapped[str]
    published: Mapped[datetime]
    company_name: Mapped[Optional[str]]
    no_of_positions: Mapped[Optional[int]]
    deadline: Mapped[Optional[datetime]]
    longitude: Mapped[Optional[float]]
    latitude: Mapped[Optional[float]]
    created_at: Mapped[datetime]
    ad_id: Mapped[int]
    occupation: Mapped[str]


class FinnJobAdsContent(Base):
    __tablename__ = "finn_job_ads__content"

    # should make id a primary key
    id: Mapped[int] = mapped_column(primary_key=True)
    keywords: Mapped[Optional[str]]
    nettverk: Mapped[Optional[str]]
    sektor: Mapped[Optional[str]]
    bransje: Mapped[Optional[str]]
    stillingsfunksjon: Mapped[Optional[str]]
    arbeidsspråk: Mapped[Optional[str]]
    job_title: Mapped[Optional[str]]
    content: Mapped[str]
    created_at: Mapped[datetime]
    hjemmekontor: Mapped[Optional[str]]
    flere_arbeidssteder: Mapped[Optional[str]]
    arbeidsgiver: Mapped[Optional[str]]
    frist: Mapped[Optional[str]]
    ansettelsesform: Mapped[Optional[str]]
    sted: Mapped[Optional[str]]
    antall_stillinger: Mapped[Optional[int]]
    lederkategori: Mapped[Optional[str]]
    stillingstittel: Mapped[Optional[str]]

# Base.metadata.create_all(get_ingestion_db_sqlalchemy_engine())