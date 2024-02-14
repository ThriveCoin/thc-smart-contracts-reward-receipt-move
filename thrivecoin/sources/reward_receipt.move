module thrivecoin::reward_receipt {
  // imports
  use sui::object::{Self, ID, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::event;
  use sui::vec_set::{Self, VecSet};
  use std::string::{Self, String};
  use sui::package;
  use sui::display;

  // errors
  const ENotWriter: u64 = 1;

  // structures
  struct AdminRole has key {
    id: UID
  }

  struct WriterRole has key {
    id: UID,
    list: VecSet<address>
  }

  struct RewardReceipt has key, store {
    id: UID,
    recipient: address,
    transfer_tx: String,
    version: String,
    timestamp: u64,
    meta_data_uri: String
  }

  struct RewardReceiptStored has copy, drop {
    reward_receipt_id: ID,
    recipient: address,
    transfer_tx: String,
    version: String,
    timestamp: u64,
    meta_data_uri: String
  }

  // OTW
  struct REWARD_RECEIPT has drop {}

  // initializer
  fun init(otw: REWARD_RECEIPT, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    let display_keys = vector[
      string::utf8(b"id"),
      string::utf8(b"recipient"),
      string::utf8(b"transfer_tx"),
      string::utf8(b"version"),
      string::utf8(b"timestamp"),
      string::utf8(b"meta_data_uri"),
    ];

    let display_values = vector[
      string::utf8(b"{id}"),
      string::utf8(b"{recipient}"),
      string::utf8(b"{transfer_tx}"),
      string::utf8(b"{version}"),
      string::utf8(b"{timestamp}"),
      string::utf8(b"{meta_data_uri}"),
    ];

    let display = display::new_with_fields<RewardReceipt>(
      &publisher, display_keys, display_values, ctx
    );
    display::update_version(&mut display);

    transfer::public_transfer(publisher, tx_context::sender(ctx));
    transfer::public_transfer(display, tx_context::sender(ctx));

    transfer::transfer(AdminRole {
      id: object::new(ctx)
    }, tx_context::sender(ctx));

    transfer::share_object(WriterRole {
      id: object::new(ctx),
      list: vec_set::singleton(tx_context::sender(ctx))
    });
  }

  // role functions
  public fun transfer_admin_role (admin_role: AdminRole, new_owner: address) {
    transfer::transfer(admin_role, new_owner);
  }

  public fun add_writer (_: &AdminRole, writer_role: &mut WriterRole, account: address) {
    vec_set::insert(&mut writer_role.list, account);
  }

  public fun del_writer(_: &AdminRole, writer_role: &mut WriterRole, account: address) {
    vec_set::remove(&mut writer_role.list, &account);
  }

  // receipt functions
  public fun add_receipt (
    writer_role: &WriterRole,
    recipient: address,
    transfer_tx: String,
    version: String,
    timestamp: u64,
    meta_data_uri: String,
    ctx: &mut TxContext
  ) {
    assert!(vec_set::contains(&writer_role.list, &tx_context::sender(ctx)), ENotWriter);

    let receipt = RewardReceipt {
      id: object::new(ctx),
      recipient,
      transfer_tx,
      version,
      timestamp,
      meta_data_uri
    };

    event::emit(RewardReceiptStored {
      reward_receipt_id: object::uid_to_inner(&receipt.id),
      recipient,
      transfer_tx,
      version,
      timestamp,
      meta_data_uri
    });

    transfer::public_freeze_object(receipt);
  }

  public fun recipient(self: &RewardReceipt): address { self.recipient }

  public fun transfer_tx(self: &RewardReceipt): String { self.transfer_tx }

  public fun version(self: &RewardReceipt): String { self.version }

  public fun timestamp(self: &RewardReceipt): u64 { self.timestamp }

  public fun meta_data_uri(self: &RewardReceipt): String { self.meta_data_uri }

  public fun writer_list(self: &WriterRole): VecSet<address> { self.list }

  #[test_only]
  public fun test_init(ctx: &mut TxContext) {
    init(REWARD_RECEIPT {}, ctx)
  }
}
